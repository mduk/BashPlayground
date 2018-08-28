# Hold Annotations
/^#@/{
  s/#@(.*)/\1/
  H
}

# Hold Function Declaration
/^[a-zA-Z_]*\(\)/{
  s/^(.*)\(.*/function: \1/
  H
}

# Hold named-argument declarations
/declare arg_/{
  s/.*declare arg_(.*)=.*/argument: \1/
  H
}

# Hold names of variables that catch positional arguments
/.*declare.*="\$[1-9]"/{
  s/.* (.*)="\$(.*)".*/argument-\2: \1/
  H
}

# Hold names of global variables referenced
/\$[A-Z]+/{
  s/.*(\$[A-Z_]+).*/references_global: \1/
  H
}

# Dump out hold buffer
/^}/{
  x
  s/^\n//;
  p
  i\

}
