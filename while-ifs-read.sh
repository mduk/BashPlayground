declare table=".business.email|Business Email
               .business.phone|Business Phone
               .technical.email|Technical Email
               .technical.phone|Technical Phone"


while IFS="|" read property label
do
  echo "property: $property"
  echo "label: $label"
  echo "remainder: $remainder"
done <<<"$table"
