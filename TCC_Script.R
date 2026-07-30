# ==============================================================================
# TCC - EXPLORAÇÃO E MODELAGEM ESTATÍSTICA DE DADOS DO LEAGUE OF LEGENDS
# ==============================================================================


# =========== #
# 1. PACOTES  #
# =========== #

if(!require(pacman)) install.packages("pacman")
pacman::p_load(tidyverse, skimr, corrplot, readxl,
               psych, mvnormtest, ggrepel, factoextra,
               cluster, gridExtra, car, pscl, pROC, blorr, DescTools)

# =============================== #
# 2. LEITURA E PRÉ-PROCESSAMENTO  #
# =============================== #

dados <- read_excel("dados.xlsx")

# Limpeza de NAs
dados_limpos <- dados %>%
  select(-`DRA@15`, -`TD@15`, -PPG)

# Histograma
dados_limpos %>%
  select(-Name, -Region, -Games) %>% 
  pivot_longer(cols = everything(), names_to = "Variavel", values_to = "Valor") %>%
  ggplot(aes(x = Valor)) +
  geom_histogram(bins = 30, fill = "steelblue", color = "black", alpha = 0.7) +
  facet_wrap(~Variavel, scales = "free") +
  theme_minimal() +
  labs(title = "Distribuição das Variáveis de Desempenho", x = "Valor", y = "Frequência")

# Matriz de Correlação
cor_geral <- cor(dados_limpos %>% select(where(is.numeric)), method = "spearman")
corrplot(cor_geral, method = "color", type = "upper", tl.col = "black", tl.cex = 0.6,
         mar = c(0,0,2,0))

# Padronização (Escore Z)
dados_padronizados <- dados_limpos %>%
  select(-Name, -Region, -`Win rate`, -Games,
         -DRAPG, -NASHPG, -`Blue%`) %>%  
  scale() %>%                 
  as.data.frame()             

# ================================= #
# 3. ANÁLISE FATORIAL EXPLORATÓRIA  #
# ================================= #

# Remoção de variáveis colineares
remover_colunas <- c("K:D", "GDM", "FP%", "GPM", "Towers killed", "Towers lost")
dados_final <- dados_padronizados %>% select(-all_of(remover_colunas))

# Testes de Adequação da Amostra
mshapiro.test(t(dados_final))
cortest.bartlett(cor(dados_final), n = nrow(dados_final))
KMO(cor(dados_final))

# Scree Plot e Análise Paralela
scree(cor(dados_final), main = "Scree Plot: Definição do Número de Fatores")
fa.parallel(dados_final, fm = "pa", fa = "fa", main = "")

# Extração (PA) com Rotação Varimax (Modelo Final)
af_tcc <- fa(r = dados_final, 
             nfactors = 2, 
             rotate = "varimax", 
             fm = "pa", 
             scores = "regression")

print(af_tcc, cut = 0.3)
fa.diagram(af_tcc, main = "Estrutura Fatorial Latente (Modelo Final)")

# Extração dos Escores Fatoriais
escores_fatoriais <- as.data.frame(af_tcc$scores)
colnames(escores_fatoriais) <- c("Escore_Objetivos", "Escore_Macro")

# Base Final para Modelagem
dados_modelagem <- dados_limpos %>%
  select(Name, Region, `Win rate`) %>%
  cbind(escores_fatoriais)

# =========================== #
# 4. AGRUPAMENTOS (CLUSTERS)  #
# =========================== #

dados_cluster <- dados_modelagem %>% select(Escore_Objetivos, Escore_Macro)
set.seed(123)

# K-MEANS (k = 3)
modelo_kmeans <- kmeans(dados_cluster, centers = 3, nstart = 50)
dados_modelagem <- dados_modelagem %>% mutate(Cluster = as.factor(modelo_kmeans$cluster))

# HIERÁRQUICO (k = 3)
dados_hc <- dados_padronizados
rownames(dados_hc) <- dados_modelagem$Name
dist_correlacao <- get_dist(dados_hc, method = "pearson")
modelo_hierarquico <- hclust(dist_correlacao, method = "ward.D2")
grupos_hierarquico <- cutree(modelo_hierarquico, k = 3)

dados_modelagem <- dados_modelagem %>% mutate(Cluster_Hierarquico = as.factor(grupos_hierarquico))

# Visualização de Dispersão K-Means
ggplot(dados_modelagem, aes(x = Escore_Objetivos, y = Escore_Macro, color = Cluster)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(size = 4, alpha = 0.8) +
  theme_minimal() +
  labs(title = "Mapeamento dos Clusters", x = "Fator 1: Pressão e Execução", y = "Fator 2: Sobrevivência e Controle de Mapa")

# ======================================== #
# 5. REGRESSÃO LOGÍSTICA (SUPERVISIONADA)  #
# ======================================== #

# Preparação da Variável Resposta (1 = Vencedora, 0 = Perdedora)
dados_regressao <- dados_final %>%
  mutate(Vencedora = as.factor(ifelse(dados_modelagem$`Win rate` > 0.5, 1, 0)))

dados_modelagem <- dados_modelagem %>%
  mutate(Vencedora = as.factor(ifelse(`Win rate` > 0.5, 1, 0)))

# --- MODELO STEPWISE (AIC) ---
modelo_completo <- glm(Vencedora ~ ., data = dados_regressao, family = binomial(link = "logit"))
modelo_stepwise <- step(modelo_completo, direction = "both", trace = 0)
summary(modelo_stepwise)
vif(modelo_stepwise)
exp(coef(modelo_stepwise))

# --- MODELO COM ESCORES FATORIAIS ---
modelo_logistico <- glm(Vencedora ~ Escore_Objetivos + Escore_Macro, 
                        data = dados_modelagem, 
                        family = binomial(link = "logit"))
summary(modelo_logistico)
vif(modelo_logistico)
exp(coef(modelo_logistico))
pR2(modelo_logistico)["McFadden"]

# --- MODELO STEPWISE POR P-VALOR (BLORR) ---
dados_brutos_regressao <- dados_final %>%
  mutate(Vencedora = as.factor(ifelse(dados_modelagem$`Win rate` > 0.5, 1, 0)))
modelo_completo_bruto <- glm(Vencedora ~ ., data = dados_brutos_regressao, family = binomial(link = "logit"))

modelo_step_pvalor <- blr_step_p_both(modelo_completo_bruto, pent = 0.05, prem = 0.05)
modelo_final_pvalor <- modelo_step_pvalor$model
summary(modelo_final_pvalor)
PseudoR2(modelo_final_pvalor, which = "Nagelkerke")

# ======================================================== #
# 6. AVALIAÇÃO PREDITIVA (MATRIZ DE CONFUSÃO E Curva ROC)  #
# ======================================================== #

# Predições e Matriz - Modelo Stepwise p-valor
probabilidades_pvalor <- predict(modelo_final_pvalor, type = "response")
predicoes_pvalor <- ifelse(probabilidades_pvalor > 0.5, 1, 0)
matriz_pvalor <- table(Real = dados_brutos_regressao$Vencedora, Predito = predicoes_pvalor)
print(matriz_pvalor)

# Predições e Matriz - Modelo Fatorial
probabilidades_logistico <- predict(modelo_logistico, type = "response")
predicoes_classe_logistico <- ifelse(probabilidades_logistico > 0.5, 1, 0)
matriz_confusao_logistico <- table(Real = dados_modelagem$Vencedora, Predito = predicoes_classe_logistico)
print(matriz_confusao_logistico)

# Curvas ROC e AUC
roc_obj_logistico <- roc(dados_modelagem$Vencedora, probabilidades_logistico, quiet = TRUE)
cat("\nÁrea sob a Curva (AUC) modelo Fatorial:", round(auc(roc_obj_logistico), 4), "\n")

plot(roc_obj_logistico, main = "Curva ROC - Modelo Fatorial Preditivo de Vitórias",
     col = "#d73027", lwd = 3, print.auc = TRUE, 
     print.auc.x = 0.4, print.auc.y = 0.2, 
     legacy.axes = TRUE)

