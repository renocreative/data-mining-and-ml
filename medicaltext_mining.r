# Text Classification Problem

library(RWeka)
library(pROC)
library(readr)


# Pre-processing
# Data Representation & Feature selection
estrogens_dataset <- read_file("units_Estrogens.txt")

# 1.	Replace all “,” by ”;”   (“,” are special character of separation for .csv files)
estrogens_dataset <- gsub(',', ';', estrogens_dataset)

# 3.	Replace all “\\r” by ”,” (Replace all carriage returns with comma separation / csv format)
estrogens_dataset <- gsub('\\r', ',', estrogens_dataset)

# 2.	Replace all “\\*\\*\\*\\*\\*\\* \\d+” 	[document ids] with carriage returns to separate data (csv format)
estrogens_dataset <- gsub('\\*\\*\\*\\*\\*\\* \\d+', '\r', estrogens_dataset)

# 4.	Remove all “,----K”      (Remove attribute name “K”. “K” represent the class of a given document)
estrogens_dataset <- gsub(',----K', '', estrogens_dataset)

# 5.	Remove all “----[A-Z]” (Remove all other attribute names)
estrogens_dataset <- gsub('----[A-Z]', '', estrogens_dataset)

# 6.	Replace all “_” by ” ”   (Separate the MeSH id into meaningful words)
estrogens_dataset <- gsub('_', ' ', estrogens_dataset)

#7.      	Save processed file for debugging
write (estrogens_dataset, file="units_Estrogens_processed.txt")

#8.		Reload processed file in order for classification task
estrogens_dataset <- read.csv("units_Estrogens_processed.txt", header=FALSE, sep = ",")

# 9.	Add "K,T,A,P,M" as colum names of the dataset
colnames(estrogens_dataset) <- c('K','T','A','P','M')

#10. 	weka.filters.unsupervised.attribute.NominalToString -C 2-3,5
fctr.cols <- sapply(estrogens_dataset, is.factor)
fctr.cols <- c(2, 3, 5)
estrogens_dataset[,  fctr.cols] <- sapply(estrogens_dataset[, fctr.cols], as.character)

#11.    	Convert the classification feature "K" to a factor variable
#estrogens_dataset$K <- factor(estrogens_dataset$K)

#weka.filters.unsupervised.attribute.StringToWordVector –R 2-3,5 –W 10000 –prune-rate -1.0 –C –N 0 –L –S 
#–stemmer weka.core.stemmers.NullStemmer –M 1 –tokenizer “weka.core.tokenizers.WordTokenizer –delimiters \” \\r\\n\\t.,;:\\\’\\\”()?!\””
word2vec <- make_Weka_filter("weka/filters/unsupervised/attribute/StringToWordVector") 
estrogens_dataset <- word2vec(K ~ ., data = estrogens_dataset, control = Weka_control(R="2,3,5", W = 10000, C = TRUE, P="attr-",
N = 0, L = TRUE, stemmer = list("weka.core.stemmers.NullStemmer –M 1"), tokenizer = list("weka.core.tokenizers.WordTokenizer") ) ) 

#weka.filters.unsupervised.attribute.Reorder -R 2-last,first
#estrogens_dataset <- rbind(estrogens_dataset[,0:-1], estrogens_dataset[,1])

#AttributeEvaluator = weka.attributeSelection.InfoGainAttributeEval
evaluator <- InfoGainAttributeEval(K ~ ., data = estrogens_dataset, control = NULL)

#SearchMethod = weka.attributeSelection.Ranker -T 0 -N -1
ranker <- make_Weka_filter("weka/filters/supervised/attribute/AttributeSelection")
rankings <- ranker(K ~ ., data=estrogens_dataset, control = Weka_control(S = list("weka.attributeSelection.Ranker -T 0 -N 500"),
E = list("weka.attributeSelection.InfoGainAttributeEval")))
attributes <- colnames(rankings)

#weka.filters.unsupervised.attribute.Remove -V –R
attr_indexes <- sapply(attributes, grep, x=colnames(estrogens_dataset))
remover <- make_Weka_filter("weka/filters/unsupervised/attribute/Remove")
indexes <- paste (c(attr_indexes, recursive = TRUE), collapse=",")
estrogens_dataset <- remover(K ~ ., data=estrogens_dataset, control = Weka_control(V=TRUE, R=indexes))
 

# we end up with a ready-to-mine dataset with the relevant 184 features
# we save this model

# Model learning
# 5x2 cross validation with NaiveBayes, SMO, J48, IBk, RandomForest, AdaBoostM1[w/ NaiveBayes]. 
# WOW("weka/classifiers/bayes/NaiveBayes")

# LazyBayes
LBR <- make_Weka_classifier("weka/classifiers/lazy/LBR", c('LBR', 'Weka_lazy'), init=make_Weka_package_loader("lazyBayesianRules"))
estrogens_bayes <- LBR(K ~ ., data = estrogens_dataset)
eval_bayes <- evaluate_Weka_classifier(estrogens_bayes, numFolds = 5, repeats = 2, complexity = FALSE, seed = 1, class = TRUE)

# SMO
estrogens_smo <- SMO(K ~ ., data = estrogens_dataset, control = Weka_control(K = list("weka.classifiers.functions.supportVector.RBFKernel", G = 2)))
eval_smo <- evaluate_Weka_classifier(estrogens_smo, numFolds = 5, repeats = 2, complexity = FALSE, seed = 1, class = TRUE)

# J48
estrogens_j48 <- J48(K ~ ., data = estrogens_dataset)
eval_j48 <- evaluate_Weka_classifier(estrogens_j48, numFolds = 5, repeats = 2, complexity = FALSE, seed = 1, class = TRUE)

#IBk
estrogens_IBk <- IBk(K ~ ., data = estrogens_dataset)
eval_IBk <- evaluate_Weka_classifier(estrogens_IBk, numFolds = 5, repeats = 2, complexity = FALSE, seed = 1, class = TRUE)

#RandomForest
#estrogens_forest <- make_Weka_classifier("weka/classifiers/trees/RandomForest")
estrogens_forest <- Bagging(K ~ ., data = estrogens_dataset, control = Weka_control(W = "weka.classifiers.trees.RandomForest"))
eval_forest <- evaluate_Weka_classifier(estrogens_forest, numFolds = 5, repeats = 2, complexity = FALSE, seed = 1, class = TRUE)

# AdaBoostM1
estrogens_m1 <- AdaBoostM1(K ~ ., data = estrogens_dataset, control = Weka_control(W = list(LBR, M = 30)))
eval_m1 <- evaluate_Weka_classifier(estrogens_m1, numFolds = 5, repeats = 2, complexity = FALSE, seed = 1, class = TRUE)

str(multiclass.roc(estrogens_dataset$K, eval_bayes))
str(multiclass.roc(estrogens_dataset$K, eval_smo))
str(multiclass.roc(estrogens_dataset$K, eval_j48))
str(multiclass.roc(estrogens_dataset$K, eval_IBk))
str(multiclass.roc(estrogens_dataset$K, eval_forest))
str(multiclass.roc(estrogens_dataset$K, eval_m1))

# We should get approx.:
# Classifier	AUC (On Average)
# NaiveBayes	0.924783
# SMO	0.7192361
# J48	0.6593662
# IBk	0.3451303
# RandomForest	0.8501737
# AdaBoostM1 (NaiveBayes)	0.8952256

