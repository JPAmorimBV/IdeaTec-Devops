set -e

echo "🏍️ IdeaTec Tecnologia - Challenge Mottu 2025"
echo "============================================="

# Variáveis do projeto
IMAGE_NAME="ideatec-mottu-api"
IMAGE_TAG="challenge"
CONTAINER_NAME="mottu-api-container"

echo "🧹 Limpando ambiente anterior..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true
docker rmi $IMAGE_NAME:$IMAGE_TAG 2>/dev/null || true

echo "🔨 Fazendo build da imagem Docker otimizada..."
docker build -t $IMAGE_NAME:$IMAGE_TAG .

echo "✅ Build concluído! Verificando imagem..."
docker images $IMAGE_NAME:$IMAGE_TAG

echo "🚀 Executando container em background..."
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p 8080:8080 \
    -p 80:8080 \
    -v mottu_data:/app/data \
    -v mottu_logs:/app/logs \
    -e SPRING_PROFILES_ACTIVE=production \
    $IMAGE_NAME:$IMAGE_TAG

echo "⏳ Aguardando inicialização (40 segundos)..."
sleep 40

echo "🔍 Verificando status do container..."
if docker ps | grep -q $CONTAINER_NAME; then
    echo "✅ Container está rodando!"
    
    # VERIFICAR USUÁRIO NÃO-ROOT (REQUISITO CHALLENGE)
    echo "🔒 Verificando usuário não-root..."
    USER_CHECK=$(docker exec $CONTAINER_NAME whoami)
    if [ "$USER_CHECK" != "root" ]; then
        echo "✅ SUCESSO: Usuário não-root confirmado: $USER_CHECK"
    else
        echo "❌ ERRO: Aplicação rodando como root!"
        exit 1
    fi
    
    # TESTAR APLICAÇÃO
    echo "🧪 Testando aplicação..."
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/actuator/health)
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "✅ Aplicação funcionando! Health check OK"
    else
        echo "⚠️ Health check retornou: $HTTP_STATUS"
    fi
 
    
else
    echo "❌ ERRO: Container não iniciou!"
    docker logs $CONTAINER_NAME
    exit 1
fi