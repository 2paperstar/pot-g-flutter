#!/bin/bash
# RSA 키 쌍 생성 스크립트
#
# 사용법:
#   ./tools/generate_rsa_keypair.sh [output_dir]
#
# 예시:
#   ./tools/generate_rsa_keypair.sh
#   ./tools/generate_rsa_keypair.sh keys

OUTPUT_DIR=${1:-keys}

echo "Generating RSA key pair..."
echo "Output directory: $OUTPUT_DIR"
echo ""

# 디렉토리 생성
mkdir -p "$OUTPUT_DIR"

# 개인키 생성 (2048비트)
echo "Generating private key..."
openssl genrsa -out "$OUTPUT_DIR/private_key.pem" 2048

# 공개키 추출
echo "Extracting public key..."
openssl rsa -in "$OUTPUT_DIR/private_key.pem" -pubout -out "$OUTPUT_DIR/public_key.pem"

echo ""
echo "✅ Key pair generated successfully!"
echo ""
echo "Files:"
echo "  Private key: $OUTPUT_DIR/private_key.pem"
echo "  Public key:   $OUTPUT_DIR/public_key.pem"
echo ""
echo "⚠️  IMPORTANT: Keep the private key secure and never commit it to version control!"
echo ""
echo "Next steps:"
echo "  1. Add public_key.pem to your .env file as API_CHANNEL_KEY_PUBLIC_KEY"
echo "  2. Use private_key.pem to generate API channel keys:"
echo "     dart run tools/generate_api_channel_key.dart qa $OUTPUT_DIR/private_key.pem"
