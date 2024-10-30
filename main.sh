#!/bin/bash

figlet -f slant suprimoware
if [ -z "$1" ]; then
    echo "Error: No enviaste un dominio"
    echo "Uso: ./main.sh <dominio>"
    exit 1
fi

dominio=$1
echo "Escaneando $dominio"

# Estructura de carpetas
timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
ruta_resultados=./resultados/$dominio/$timestamp
mkdir -p "$ruta_resultados"
mkdir -p "$ruta_resultados/raw"
mkdir -p "$ruta_resultados/clean"

# Análisis de infraestructura
## Con DIG
dig +short A "$dominio" > "$ruta_resultados/clean/IP"
dig +short MX "$dominio" > "$ruta_resultados/clean/MX"
dig +short TXT "$dominio" > "$ruta_resultados/clean/TXT"
dig +short NS "$dominio" > "$ruta_resultados/clean/NS"
dig +short SRV "$dominio" > "$ruta_resultados/clean/SRV"
dig +short AAAA "$dominio" > "$ruta_resultados/clean/AAAA"
dig +short CNAME "$dominio" > "$ruta_resultados/clean/CNAME"
dig +short SOA "$dominio" > "$ruta_resultados/clean/SOA"
dig +short txt _dmarc.$dominio > "$ruta_resultados/clean/DMARC"
dig +short txt default._domainkey.$dominio > "$ruta_resultados/clean/DKIM"

## Con KATANA

katana -u "$dominio" > "$ruta_resultados/raw/katana"
katana -u "$dominio" | sort -u | httpx -silent >> "$ruta_resultados/clean/paths"

## Con CTFR

#ctfr -d "$dominio" -o "$ruta_resultados/raw/ctfr"
#cat "$ruta_resultados/raw/ctfr" | sort -u | httpx -silent >> "$ruta_resultados/clean/paths"

## Con GAU

gau "$dominio" > "$ruta_resultados/raw/gau"
gau "$dominio" | sort -u | httpx -silent  >> "$ruta_resultados/clean/dominios"

echo "Extrayendo rangos de IP"
while IFS= read -r ip; do
    whois -b "$ip" | grep 'inetnum' | awk '{print $2, $3, $4}' >> "$ruta_resultados/clean/rangos_ripe"
done < "$ruta_resultados/clean/IP"

echo "Realizando whois"
whois "$dominio" > "$ruta_resultados/raw/whois"
echo "Realizando dig"
dig "$dominio" > "$ruta_resultados/raw/dig"

curl -I https://"$dominio" > "$ruta_resultados/raw/headers"
cat "$ruta_resultados/raw/headers" | grep -i Server | awk '{ print $2 }' > "$ruta_resultados/clean/header_server"

# Revisar y eliminar archivos vacíos en la carpeta /clean
for file in "$ruta_resultados/clean"/*; do
  if [ ! -s "$file" ]; then
    echo "Eliminando archivo vacío: $file"
    rm "$file"
  fi
done


# Crear el archivo con el encabezado del dominio
echo "# $dominio" > "resultado.md"
echo "## Infraestructura" >> "resultado.md"

# Función para agregar contenido de archivos a una sección específica
function agregar_registros {
    tipo_registro=$1
    archivo_registro="$ruta_resultados/clean/$tipo_registro"
    
    # Solo agregar la sección si el archivo tiene contenido
    if [[ -s "$archivo_registro" ]]; then
        echo "### $tipo_registro" >> "resultado.md"
        
        # Cambiar aquí para añadir tres # al inicio de cada línea
        sed 's/^/#### /' "$archivo_registro" >> "resultado.md"
        
        echo "" >> "resultado.md"  # AñadeNS una línea en blanco para separar secciones
    fi
}

# Agregar diferentes tipos de registros
agregar_registros "IP"
agregar_registros "NS"
agregar_registros "MX"
agregar_registros "TXT"
agregar_registros "CNAME"
agregar_registros "SRV"
agregar_registros "AAAA"
agregar_registros "SOA"
agregar_registros "rangos_ripe"
agregar_registros "header_server"
agregar_registros "DMARC"
agregar_registros "DKIM"


# Generar el mapa mental con markmap
markmap "resultado.md" --no-open
