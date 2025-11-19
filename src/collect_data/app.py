import json
import random

def lambda_handler(event, context):
    """
    Simula a coleta de um preço de produto.
    Em produção, aqui ocorreria um web scraping ou chamada a um sistema externo.
    """
    try:
        # Define um ID de produto fixo para o teste inicial de orquestração.
        # Em um projeto real, você poderia buscar uma lista de IDs do DynamoDB.
        product_id = 'PROD-12345' 

        # Simulação de Preço: Gera um preço aleatório para fins de teste.
        # Isso garante que a lógica de "preço mudou" seja testada ocasionalmente.
        current_price = round(random.uniform(50.00, 150.00), 2) 

        print(f"Produto: {product_id}, Preço Coletado: {current_price}")
        
        # Retorna o preço coletado para a próxima etapa (ProcessDataFunction no Step Functions)
        return {
            'productId': product_id,
            'currentPrice': current_price
        }

    except Exception as e:
        print(f"Erro na coleta de dados: {e}")
        # É fundamental levantar o erro para o Step Functions conseguir capturar e lidar com a falha.
        raise e