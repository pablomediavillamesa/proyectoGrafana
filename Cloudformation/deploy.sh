#!/bin/bash

set -e  # Detiene la ejecución si ocurre un error

# === Nombres de los stacks ===
STACK_VPC="Cloudformation-VPC"
STACK_SG="Cloudformation-SG"
STACK_EC2="Cloudformation-EC2"
KEY_NAME="ola"
KEY_FILE="${KEY_NAME}.pem"

# === Archivos YAML ===
VPC_FILE="Cloudformation-vpc.yaml"
SG_FILE="Cloudformation-sg.yaml"
EC2_FILE="Cloudformation-ec2.yaml"

# === Opción --force-redeploy ===
FORCE_REDEPLOY=false
if [[ "$1" == "--force-redeploy" ]]; then
    FORCE_REDEPLOY=true
    echo "Modo de reimplementación forzada activado."
fi

# 1. Verificar clave SSH
echo "Verificando clave SSH ($KEY_NAME)..."
if ! aws ec2 describe-key-pairs --key-names "$KEY_NAME" &>/dev/null; then
    echo "Clave no existe. Creando..."
    aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$KEY_FILE"
    chmod 400 "$KEY_FILE"
    echo "Clave guardada como $KEY_FILE"
else
    echo "La clave SSH ya existe."
fi
echo ""

# 2. Validar archivos YAML
echo "Validando plantillas YAML..."
for file in "$VPC_FILE" "$SG_FILE" "$EC2_FILE"; do
    aws cloudformation validate-template --template-body file://"$file"
    echo "$file es válido."
done
echo ""

# 3. Eliminar stacks anteriores si se solicita
if [ "$FORCE_REDEPLOY" = true ]; then
    echo "Eliminando stacks anteriores..."
    for stack in "$STACK_EC2" "$STACK_SG" "$STACK_VPC"; do
        echo "Eliminando stack $stack..."
        aws cloudformation delete-stack --stack-name "$stack"
    done
    echo "Esperando a que los stacks se eliminen completamente..."
    for stack in "$STACK_EC2" "$STACK_SG" "$STACK_VPC"; do
        aws cloudformation wait stack-delete-complete --stack-name "$stack" || true
    done
    echo "Stacks eliminados correctamente."
    echo ""
fi

# 4. Crear VPC
echo "Creando stack de VPC ($STACK_VPC)..."
aws cloudformation create-stack \
    --stack-name "$STACK_VPC" \
    --template-body file://"$VPC_FILE" \
    --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-create-complete --stack-name "$STACK_VPC"
echo "VPC creada exitosamente."
echo ""

# 5. Crear grupos de seguridad
echo "Creando stack de Security Groups ($STACK_SG)..."
aws cloudformation create-stack \
    --stack-name "$STACK_SG" \
    --template-body file://"$SG_FILE" \
    --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-create-complete --stack-name "$STACK_SG"
echo "Security Groups creados correctamente."
echo ""

# 6. Crear instancias EC2
echo "Creando stack de instancias EC2 ($STACK_EC2)..."
aws cloudformation create-stack \
    --stack-name "$STACK_EC2" \
    --template-body file://"$EC2_FILE" \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameters ParameterKey=KeyName,ParameterValue="$KEY_NAME"
aws cloudformation wait stack-create-complete --stack-name "$STACK_EC2"
echo "Instancias EC2 desplegadas correctamente."
echo ""

echo "Despliegue completo del entorno proyectoGrafana."
