while IFS= read -r domain; do
    python3 get-asn-hackertarget.py --input "$domain" --output "output/"
done < domains_definitive