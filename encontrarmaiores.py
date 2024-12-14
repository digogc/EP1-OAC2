def encontrar_tres_maiores_valores(arquivo):
    with open(arquivo, 'r') as file:
        valores = file.readlines()
    
    linhas_valores = []

    for i, valor in enumerate(valores, start=1):
        try:
            numero = float(valor.strip())
            linhas_valores.append((numero, i))
        except ValueError:
            print(f"Valor inválido na linha {i}: '{valor.strip()}'")

    # Ordenar por valor em ordem decrescente
    linhas_valores.sort(reverse=True, key=lambda x: x[0])

    # Selecionar os 3 maiores
    tres_maiores = linhas_valores[:3]
    
    return tres_maiores


# Exemplo de uso:
nome_arquivo = 'xTrain.txt'
maiores_valores = encontrar_tres_maiores_valores(nome_arquivo)
for valor, linha in maiores_valores:
    print(f"Valor: {valor}, encontrado na linha: {linha}.")