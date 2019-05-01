declare debug=${HTTP_DEBUG:-false}

source ./array-assoc-utils.sh

########################################################################
# Initialise associative arrays that don't already exist
########################################################################
init_global_assoc() {
  for assoc
  do
    if ! declare -p "$assoc" &>/dev/null
    then declare -Ag "${assoc}=()"
    fi
  done
}

init_global_assoc \
  HTTP_REQUEST_ALIASES \
  HTTP_REQUEST_HEADERS \
  HTTP_REQUEST_QUERY \
  HTTP_REQUEST_MATLS

declare -Ag PARAM_RULES=(
  [url]='//^https?://.+'
  [no-spaces]='//^[^ ]+$'
  [only-digits]='//^[0-9]+$'
  [yes-no]='/^(yes|no|YES|NO)$'
)

HTTP_urlencode() {
  while [[ $# -gt 0 ]]
  do
    # Key
    echo -n "${1%:}"
    shift

    if [[ -n "$1" ]] && ! [[ "$1" == *: ]]
    then
      echo -n "=$1"
      shift
    fi

    echo -n '&'

  done | sed 's/&$//' # strip off trailing ampersand
}


HTTP() {
  if [[ $1 != *: ]]
  then
    case "$1" in

      urlencode)
        shift
        HTTP_urlencode "$@"
        return
        ;;

      authbasic)
        shift
        base64 <<<"$2:$3"
        return
        ;;

      raw|raw*)
        if [[ $1 == raw[* ]]
        then declare reqdir="${HTTP_REQUEST_ALIASES[$(sed -E 's/raw\[([a-zA-Z]+)\]/\1/' <<< "$1")]}"
        else declare reqdir="$HTTP_LAST_REQDIR"
        fi
        cat "$reqdir/raw.http"
        return
        ;;

      request|request*)
        if [[ $1 == request[* ]]
        then declare reqdir="${HTTP_REQUEST_ALIASES[$(sed -E 's/request\[([a-zA-Z]+)\]/\1/' <<< "$1")]}"
        else declare reqdir="$HTTP_LAST_REQDIR"
        fi

        case "$2" in

          headers)
            cat "$reqdir/request.headers.http" | tr -d '\r'
            return
            ;;

          header)
            if [[ -z "$3" ]]
            then
              err 'No header specified!'
              return 1
            fi
            sed -E -n "/^$3: (.+)\r/s//\1/p" "$reqdir/request.headers.http" # Don't forget the \r!
            shift
            return
            ;;

          body)
            cat "$reqdir/request.body.http"
            return
            ;;

          '')
            cat "$reqdir/request.http"
            return
            ;;

        esac
        ;;

      response|response*)
        if [[ $1 == response[* ]]
        then declare reqdir="${HTTP_REQUEST_ALIASES[$(sed -E 's/response\[([a-zA-Z]+)\]/\1/' <<< "$1")]}"
        else declare reqdir="$HTTP_LAST_REQDIR"
        fi

        case "$2" in

          file)
            echo "$reqdir/response.http"
            return
            ;;

          status)
            sed -n -E '/^HTTP\/[0-9]\.[0-9] ([0-9]{3}).*/s//\1/p' "$reqdir/response.headers.http"
            return
            ;;

          headers)
            cat "$reqdir/response.headers.http" | tr -d '\r'
            return
            ;;

          header)
            if [[ -z "$3" ]]
            then
              err 'HTTP: No header specified!'
              return 1
            fi
            sed -E -n "/^$3: (.+)\r/s//\1/p" "$reqdir/response.headers.http" # Don't forget the \r!
            shift
            return
            ;;

          body)
            case "$3" in

              file)
                echo "$reqdir/response.body.http"
                return
                ;;

              property)
                declare content_type="$(HTTP "$1" header Content-Type)"
                case "$content_type" in

                  'application/json')
                    if [[ -z "$4" ]]
                    then
                      err 'HTTP: You must specify a JQ selector!'
                      return 1
                    fi
                    jq -rcM "$4" "$(HTTP "$1" body file)"
                    return
                    ;;

                  *)
                    err "HTTP: Sorry, I don't know how to interpret a [Content-Type: $content_type] response!"
                    return 2

                esac
                return
                ;;

              '')
                cat "$reqdir/response.body.http"
                return
                ;;

            esac
            ;;

          '')
            cat "$reqdir/response.http"
            return
            ;;
        esac
        ;;
    esac
  fi

  declare param_GET=''
  declare param_GET_rules=':url'
  declare param_PUT=''
  declare param_PUT_rules=':url'
  declare param_POST=''
  declare param_POST_rules=':url'
  declare param_DELETE=''
  declare param_DELETE_rules=':url'

  declare param_alias=''
  declare param_alias_rules=':no-spaces'

  declare param_timeout="${HTTP_TIMEOUT:-5}"
  declare param_timeout_rules=':only-digits'

  declare param_verify="${HTTP_VERIFY:-no}"
  declare param_verify_rules=':yes-no'

  declare param_method=""
  declare param_method_rules='/^(HEAD|OPTIONS|GET|POST|PUT|DELETE)$'

  declare param_url=""
  declare param_url_rules=':url'

  declare param_body=""
  declare param_body_rules='-e'

  declare param_query=''
  declare param_headers=''
  declare param_matls=''

  source ./advanced-argument-parser.sh

  if [[ -z $param_method ]] && [[ -z $param_url ]]
  then
    for method in GET POST PUT DELETE HEAD OPTIONS
    do
      declare -n param="param_$method"
      if [[ -n $param ]]
      then
        declare param_method="$method"
        declare param_url="$param"
        break
      fi
    done
  fi

  if [[ -z $param_method ]] || [[ -z $param_url ]]
  then
    echo 'HTTP: You must specify at least a Method and URL' >&2
    return 1
  fi

  # Collate Headers
  declare -A headers=() assoc_headers=()
  [[ -n $param_headers ]] && array_to_assoc param_headers assoc_headers
  assoc_merge headers HTTP_REQUEST_HEADERS assoc_headers
  [[ $debug == 'true' ]] && var_dump HTTP_REQUEST_HEADERS assoc_headers headers

  # Collate Query Parameters
  declare -A query=() assoc_query=()
  [[ -n $param_query ]] && array_to_assoc param_query assoc_query
  assoc_merge query HTTP_REQUEST_QUERY assoc_query
  [[ $debug == 'true' ]] && var_dump HTTP_REQUEST_HEADERS assoc_query query

  # Collate MA-TLS Config
  declare -A matls=() assoc_matls=()
  [[ -n $param_matls ]] && array_to_assoc param_matls matls
  assoc_merge matls HTTP_REQUEST_MATLS assoc_matls
  [[ $debug == 'true' ]] && var_dump HTTP_REQUEST_MATLS assoc_matls matls

  # Build Query String
  declare querystring=''
  if [[ ${#param_query[@]} -gt 0 ]]
  then
    if [[ ${#param_query[@]} -eq 1 ]]
    then querystring="$param_query"
    else querystring="?$(HTTP_urlencode "${param_query[@]}")"
    fi
  fi

  # Build Authorization Header
  if [[ ${#param_auth[@]} -gt 0 ]]
  then
    if [[ ${#param_auth[@]} -eq 1 ]]
    then headers[Authorization]="$param_auth"
    else
      case "${param_auth[0]}" in

         basic|Basic)
           if [[ ${#param_auth[@]} -lt 3 ]]
           then
             echo 'HTTP: auth: basic: requires two parameters, username and password.' >&2
             return
           fi

           headers[Authorization]="Basic $(base64 <<<"${param_auth[1]}:${param_auth[2]}")"
           ;;

        bearer|Bearer)
          if [[ ${#param_auth[@]} -lt 2 ]]
          then
            echo 'HTTP: auth: bearer: requires one parameter, the bearer token.' >&2
            return
          fi

          headers[Authorization]="Bearer ${param_auth[1]}"
          ;;

        *)
          echo "Unknown auth: [${param_auth[0]}]" >&2
          return
          ;;

      esac
    fi
  fi

  # Assemble HTTPie Command String
  declare cmdstring="http --verbose --follow "
  cmdstring+="--timeout '$param_timeout' "
  cmdstring+="--verify '$param_verify' "

  if [[ -n "$param_matls" ]]
  then
    cmdstring+="--cert '${matls['cert']}' "
    if [[ -n "${matls['key']}" ]]
    then cmdstring+="--cert-key '${matls['key']}' "
    fi
  fi

  cmdstring+="'$param_method' '$param_url' "

  for h in "${!headers[@]}"
  do cmdstring+="'${h}:${headers[$h]}' "
  done

  for q in "${!query[@]}"
  do cmdstring+="'${q}==${query[$q]}' "
  done

  declare reqdir="$(mktemp -d)"

  if [[ -n "$param_alias" ]]
  then HTTP_REQUEST_ALIASES["$param_alias"]="$reqdir"
  fi

  declare rawfile="$reqdir/raw.http"
  cmdstring+=">'$rawfile' "

  declare errorfile="$reqdir/error.log"
  cmdstring+="2>'$errorfile' "

  declare bodyfile=''
  if [[ -e "$param_body" ]]
  then
    bodyfile="$reqdir/request.given.body.http"
    cp "$param_body" "$bodyfile"
    cmdstring+="<'$bodyfile'"
  fi

  # Execute Request
  eval "$cmdstring"
  declare -i exitcode=$?

  if [[ $exitcode == 0 ]]
  then
    declare requestfile="$reqdir/request.http"
    declare responsefile="$reqdir/response.http"
    sed -n ':a; p; n; /^HTTP/q; ba;' <"$rawfile" >"$requestfile"
    sed -n '/^HTTP/{ p; :a; n; p; ba; }' <"$rawfile" >"$responsefile"

    declare requestheadersfile="$reqdir/request.headers.http"
    declare requestbodyfile="$reqdir/request.sent.body.http"
    sed -n ':a; p; n; /^\s*$/q; ba;' <"$requestfile" >"$requestheadersfile"
    sed -n '/^\s*$/{ :a; n; p; ba; }' <"$requestfile" >"$requestbodyfile"

    declare responsestatusfile="$reqdir/response.status.http"
    declare responseheadersfile="$reqdir/response.headers.http"
    declare responsebodyfile="$reqdir/response.body.http"
    sed -n -E '/^HTTP\/[0-9]\.[0-9] ([0-9]{3}) (.*)$/s//\1 \2/p' <"$responsefile" >"$responsestatusfile"
    sed -n ':a; p; n; /^\s*$/q; ba;' <"$responsefile" >"$responseheadersfile"
    sed -n '/^\s*$/{ :a; n; p; ba; }' <"$responsefile" >"$responsebodyfile"
  else
    cat "$errorfile"
  fi

  declare -g HTTP_LAST_REQDIR="$reqdir"

  return $exitcode
}

HTTP \
  timeout: 60 \
  verify: yes \
  POST: http://localhost/as/token.oauth \
  query: [ \
    hello: world \
  ] \
  body: <(
    HTTP urlencode \
      grant_type: client_credentials \
      client_id: foo \
  ) \
  auth: [ basic "client_id" 'client_secret' ] \
  headers: [ \
    Content-Type: application/json \
    Accept: application/jwk+json \
  ]
