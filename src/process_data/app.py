import os
import boto3
from datetime import datetime
import uuid

# Inicializa o cliente DynamoDB e pega os nomes das tabelas das variáveis de ambiente
dynamodb = boto3.resource('dynamodb')
PRODUTOS_TABLE = os.environ.get('PRODUTOS_TABLE')
HISTORICO_TABLE = os.environ.get('HISTORICO_TABLE')

def get_last_price(product_id):
    """ Busca o último preço conhecido na tabela principal de Produtos. """
    table = dynamodb.Table(PRODUTOS_TABLE)
    response = table.get_item(
        Key={'productId': product_id},
        ProjectionExpression='lastKnownPrice'
    )
    # Retorna o preço se existir. Caso contrário (primeira vez), retorna 0.00.
    return response.get('Item', {}).get('lastKnownPrice', 0.00)

def update_tables(product_id, current_price, last_price):
    """ 
    Atualiza a tabela de Produtos com o novo preço e insere um registro
    na tabela de Histórico.
    """
    
    # 1. Atualiza Tabela de Produtos (put_item sobrescreve ou cria)
    produtos_table = dynamodb.Table(PRODUTOS_TABLE)
    produtos_table.put_item(
        Item={
            'productId': product_id,
            'lastKnownPrice': current_price,
            'updatedAt': datetime.now().isoformat()
        }
    )
    
    # 2. Insere na Tabela de Histórico
    historico_table = dynamodb.Table(HISTORICO_TABLE)
    historico_table.put_item(
        Item={
            'historyId': str(uuid.uuid4()), # Garantindo ID único
            'productId': product_id,
            'oldPrice': last_price,
            'newPrice': current_price,
            'timestamp': datetime.now().isoformat()
        }
    )
    print(f"Histórico ATUALIZADO para {product_id}: {last_price} -> {current_price}")


def lambda_handler(event, context):
    """ Processa os dados de preço coletados. """
    
    product_id = event['productId']
    current_price = event['currentPrice']

    # 1. Busca o último preço
    last_price = get_last_price(product_id)

    price_changed = False
    
    # 2. Lógica de Comparação
    if current_price != last_price:
        update_tables(product_id, current_price, last_price)
        price_changed = True
    else:
        print(f"Preço do produto {product_id} não mudou: {current_price}")

    # Retorna a flag para o Step Functions
    return {
        'productId': product_id,
        'currentPrice': current_price,
        'priceChanged': price_changed 
    }