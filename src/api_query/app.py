import os
import boto3
import json
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
PRODUTOS_TABLE = os.environ.get('PRODUTOS_TABLE')
HISTORICO_TABLE = os.environ.get('HISTORICO_TABLE')

def lambda_handler(event, context):
    """
    Busca o preço atual e o histórico para expor via API Gateway.
    O ID do produto é esperado no pathParameters (ex: /produtos/PROD-12345)
    """
    try:
        # Extrai o ID do produto da requisição API Gateway
        product_id = event['pathParameters']['productId']

        # 1. Buscar Preço Atual
        produtos_table = dynamodb.Table(PRODUTOS_TABLE)
        produto = produtos_table.get_item(Key={'productId': product_id}).get('Item', None)
        
        if not produto:
            return {
                'statusCode': 404,
                'body': json.dumps({'message': f'Produto {product_id} não encontrado.'})
            }

        # 2. Buscar Histórico (Usando GSI ou KeyCondition - usaremos a chave principal por enquanto)
        historico_table = dynamodb.Table(HISTORICO_TABLE)
        historico_response = historico_table.query(
            KeyConditionExpression=Key('productId').eq(product_id) # Atenção: historyId é a PK, mas usaremos Query de Exemplo
        )

        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'produtoAtual': produto,
                'historico': historico_response.get('Items', [])
            })
        }

    except Exception as e:
        print(f"Erro na consulta da API: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': f'Erro interno: {str(e)}'})
        }