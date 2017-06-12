source('bayes_fun.R')

abtrain <- factorize_data(read.csv('abtrain.sodis.csv', stringsAsFactors=FALSE))
save(abtrain, file='abtrain.Rdata')

abtrain0 <- subset(abtrain, blk==0)
save(abtrain0, file='abtrain0.Rdata')
rm(abtrain0)

abtrain1 <- subset(abtrain, blk==1)
save(abtrain1, file='abtrain1.Rdata')
rm(abtrain1)

abtrain2 <- subset(abtrain, blk==2)
save(abtrain2, file='abtrain2.Rdata')
rm(abtrain2)

abtrain3 <- subset(abtrain, blk==3)
save(abtrain3, file='abtrain3.Rdata')
rm(abtrain3)

abtrain4 <- subset(abtrain, blk==4)
save(abtrain4, file='abtrain4.Rdata')
rm(abtrain4)

abtrain5 <- subset(abtrain, blk==5)
save(abtrain5, file='abtrain5.Rdata')
rm(abtrain5)

abtrain6 <- subset(abtrain, blk==6)
save(abtrain6, file='abtrain6.Rdata')
rm(abtrain6)

abtrain9 <- subset(abtrain, blk==9)
save(abtrain9, file='abtrain9.Rdata')
rm(abtrain9)

abtrain_0_2 <- subset(abtrain, blk >= 0 & blk <= 2)
save(abtrain_0_2, file='abtrain_0_2.Rdata')
rm(abtrain_0_2)

abtrain_10_12 <- subset(abtrain, blk >= 10 & blk <= 12)
save(abtrain_10_12, file='abtrain_10_12.Rdata')
rm(abtrain_10_12)

abtrain_13_15 <- subset(abtrain, blk >= 13 & blk <= 15)
save(abtrain_13_15, file='abtrain_13_15.Rdata')
rm(abtrain_13_15)

abtrain_16_18 <- subset(abtrain, blk >= 16 & blk <= 18)
save(abtrain_16_18, file='abtrain_16_18.Rdata')
rm(abtrain_16_18)

abtrain_19_21 <- subset(abtrain, blk >= 19 & blk <= 21)
save(abtrain_19_21, file='abtrain_19_21.Rdata')
rm(abtrain_19_21)

abtrain_22_24 <- subset(abtrain, blk >= 22 & blk <= 24)
save(abtrain_22_24, file='abtrain_22_24.Rdata')
rm(abtrain_22_24)

abtrain_25_27 <- subset(abtrain, blk >= 25 & blk <= 27)
save(abtrain_25_27, file='abtrain_25_27.Rdata')
rm(abtrain_25_27)

abtrain_28_30 <- subset(abtrain, blk >= 28 & blk <= 30)
save(abtrain_28_30, file='abtrain_28_30.Rdata')
rm(abtrain_28_30)

abtrain_3_5 <- subset(abtrain, blk >= 3 & blk <= 5)
save(abtrain_3_5, file='abtrain_3_5.Rdata')
rm(abtrain_3_5)

abtrain_6_8 <- subset(abtrain, blk >= 6 & blk <= 8)
save(abtrain_6_8, file='abtrain_6_8.Rdata')
rm(abtrain_6_8)

abtest <- factorize_data(read.csv('abtest.sodis.csv', stringsAsFactors=FALSE))
save(abtest, file='abtest.Rdata')
