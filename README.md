# Exploração e Modelagem Estatística de Dados do League of Legends

[![Status](https://img.shields.io/badge/status-concluído-brightgreen.svg)]() [![License](https://img.shields.io/badge/license-MIT-green.svg)]() [![R](https://img.shields.io/badge/R-%3E=4.5.1-276DC3.svg)]() [![Made with love](https://img.shields.io/badge/made%20with-%E2%9D%A4-red.svg)]()

Este repositório abriga os scripts, dados e visualizações gerados no desenvolvimento do projeto de modelagem estatística do cenário competitivo de e-sports. O trabalho foca na análise tática e de desempenho de equipes profissionais durante a Temporada 14 de League of Legends.

## Sobre o Projeto

O volume massivo de dados gerado em partidas de nível profissional apresenta alta dimensionalidade e forte multicolinearidade. Para superar esse ruído e extrair inteligência analítica, este projeto adota uma abordagem mista de aprendizado de máquina:
*   **Análise Não Supervisionada:** Mapeamento de dimensões latentes e identificação da "identidade tática" das equipes.
*   **Análise Supervisionada:** Modelagem preditiva para estimar matematicamente o peso de cada fundamento nas chances de vitória.

## Estrutura do Repositório

*   **`data/`**: Diretório contendo a base de dados original (`dados.xlsx`) agregada por equipe.
*   **`plots/`**: Repositório de visualizações exportadas, incluindo mapas de calor de cargas fatoriais, dendrogramas, gráficos de dispersão espacial dos clusters e Curvas ROC.
*   **`TCC_Script.R`**: Script principal contendo o pipeline completo, desde o tratamento dos dados e redução de dimensionalidade até a modelagem logística e avaliação preditiva.

## Metodologia e Resultados

*   **Análise Fatorial Exploratória (AFE):** Aplicação de rotação ortogonal (Varimax) para reduzir 15 variáveis de desempenho bruto a dois eixos estratégicos independentes: "Pressão e Execução" e "Sobrevivência e Controle de Mapa". Estes fatores explicam 56% da variância total do modelo.
*   **Agrupamento (K-Means):** Utilização dos escores fatoriais para classificar o ecossistema competitivo em três perfis comportamentais claros: o Caos Tático, a Elite Proativa e o Conservadorismo Passivo.
*   **Regressão Logística Múltipla:** Modelagem da probabilidade de vitória utilizando as dimensões latentes como preditores, mitigando o risco de *overfitting* e entregando um modelo parcimonioso. O preditor final alcançou 95,92% de acurácia global e uma Área sob a Curva (AUC) de 0,994.

## Tecnologias e Dependências

O pipeline foi desenvolvido na linguagem **R**, baseando-se nos seguintes pacotes fundamentais:
*   `tidyverse`, `readxl` e `skimr` (Importação e manipulação de dados)
*   `psych` e `mvnormtest` (Diagnóstico e Extração Fatorial)
*   `factoextra` e `cluster` (Determinação do k ótimo e Agrupamento)
*   `pROC` e `blorr` (Avaliação preditiva e diagnósticos do modelo logístico)
*   `ggplot2` e `corrplot` (Visualização gráfica avançada)

---
**Autor:** Thiago de Oliveira Senra
