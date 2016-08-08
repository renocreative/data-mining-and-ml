# Text Classification Problem

# Pre-processing
# Data Representation & Feature selection
estrogens_dataset = read.csv("units_Estrogens.txt",header=TRUE)
gsub(',', ';', estrogens_dataset)
gsub('\*\*\*\*\*\* \d+', '', estrogens_dataset)
gsub('\r-', ',', estrogens_dataset)
gsub('---K', '', estrogens_dataset)
gsub('---[A-Z]', estrogens_dataset)
gsub('_', '', estrogens_dataset)

#1)	Replace all “,” by ”;”   (“,” are special character of separation for .csv files)
#2)	Remove all “\*\*\*\*\*\* \d+” 	[document ids]
#3)	Replace all “\r-” by ”,” (Remove all carriage returns)
#4)	Remove all “,---K”      (Remove attribute name “K”. “K” represent the class of a given document)
#5)	Remove all “---[A-Z]” (Remove all other attribute names)
#6)	Replace all “_” by ” ”   (Separate the MeSH id into meaningful words)
#7)	Add "K,T,A,P,M" at the first line to the file and save as a ".csv"

#weka.filters.unsupervised.attribute.NominalToString -C 2-3,5
fctr.cols <- sapply(X, is.factor)
fctr.cols = fctr.cols.remove(0) 
X[, fctr.cols] <- sapply(X[, fctr.cols], as.character)

#weka.filters.unsupervised.attribute.Reorder -R 2-last,first

#weka.filters.unsupervised.attribute.StringToWordVector –R 2-3,5 –W 10000 –prune-rate -1.0 –C –N 0 –L –S –stemmer weka.core.stemmers.NullStemmer –M 1 –tokenizer “weka.core.tokenizers.WordTokenizer –delimiters \” \\r\\n\\t.,;:\\\’\\\”()?!\””

#AttributeEvaluator = weka.attributeSelection.InfoGainAttributeEval
InfoGainAttributeEval(formula, data, subset, na.action, control = NULL)

#SearchMethod = weka.attributeSelection.Ranker -T 0 -N -1

#weka.filters.unsupervised.attribute.Remove -V –R

# we end up with a ready-to-mine dataset with the relevant 184 features
# we save this model

# Model learning
# 5x2 cross validation with NaiveBayes, SMO, J48, IBk, RandomForest, AdaBoostM1[w/ NaiveBayes]. 

# We should get:
# Classifier	AUC (On Average)
# NaiveBayes	0.924783
# SMO	0.7192361
# J48	0.6593662
# IBk	0.3451303
# RandomForest	0.8501737
# AdaBoostM1 (NaiveBayes)	0.8952256

