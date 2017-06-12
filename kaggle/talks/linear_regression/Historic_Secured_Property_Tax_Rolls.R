# This is the R code for the slides
#

library(xtable)
library(ggplot2)
library(car)
options(xtable.comment = FALSE)
train <- read.csv('property_train.csv')
value_breaks=c(1e4,1e5,1e6,1e7)
value_labels=c('$10k','$100k','$1M','$10M')

tab <- xtable(head(train,3))
print(tab, type="latex", size="\\fontsize{6pt}{8pt}\\selectfont")


qplot(total_value, 100*ecdf(total_value)(total_value), data=train, geom='line')+scale_x_log10(breaks=value_breaks, labels=value_labels)+xlab("Value")+ylab("% houses <= Value")+ggtitle("distribution of value")

# fix date columns
train$recordation_date <- as.Date(train$recordation_date, format='%m/%d/%Y')
train$change_date <- as.Date(train$change_date, format='%m/%d/%Y')
train$sales_date <- as.Date(train$sales_date, format='%m/%d/%Y')
train$p13_date <- as.Date(train$p13_date, format='%Y-%m-%d')
value_x_scale <- scale_x_log10(breaks=value_breaks, labels=value_labels)
value_y_scale <- scale_y_log10(breaks=value_breaks, labels=value_labels)

ggplot(aes(x=sqft, y=total_value), data=train)+value_y_scale+geom_point(shape=1)

qplot(factor(bedrooms), total_value, data=train, geom='boxplot')+value_y_scale

qplot(factor(bathrooms), total_value, data=train, geom='boxplot')+value_y_scale

qplot(neighborhood, total_value, data=train, geom='boxplot')+value_y_scale+theme(axis.text.x = element_text(angle = 90, hjust = 1))


ggplot(aes(x=p13_date, y=total_value), data=train)+value_y_scale+geom_point(shape=1)


m1 <- lm(total_value ~ sqft + bathrooms + neighborhood,
         data=train)

residualPlot(m1)

qqnorm(m1$residuals); qqline(m1$residuals, col='red')


train$lvalue <- log10(train$total_value)
m2 <- lm(lvalue ~ sqft + bathrooms + neighborhood,
         data=train)
c(summary(m2)$r.squared, BIC(m2))

qqnorm(m2$residuals); qqline(m2$residuals, col='red')


junk <- residualPlots(m2)


train$lsqft <- log10(train$sqft)
m3 <- lm(lvalue ~ lsqft + bathrooms + neighborhood,
         data=train)
c(summary(m3)$r.squared, BIC(m3))

junk <- residualPlots(m3, ~ lsqft)


m4 <- lm(lvalue ~ lsqft + I(lsqft^2) + bathrooms + 
         neighborhood, data=train)
c(summary(m4)$r.squared, BIC(m4))

junk <- residualPlots(m4, ~ lsqft + I(lsqft^2))


m5 <- lm(lvalue ~ lsqft + I(lsqft^2) + bathrooms
         + I(bathrooms^2) + neighborhood, data=train)
c(summary(m5)$r.squared, BIC(m5))

junk <- residualPlots(m5, ~ bathrooms + I(bathrooms^2))


junk <- residualPlots(m5, ~ neighborhood)


m6 <- lm(lvalue ~ lsqft + I(lsqft^2) + bathrooms 
         + neighborhood + lsqft:neighborhood, 
         data=train)
c(summary(m6)$r.squared, BIC(m6))

junk <- residualPlots(m5, ~ lsqft*neighborhood)



