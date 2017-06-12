library(dplyr)

pgsrc <- dplyr::src_postgres(dbname='expedia')
test <- dplyr::tbl(pgsrc, 'test')
r_im <- dplyr::tbl(pgsrc, 'r_im')
r_dtype <- dplyr::tbl(pgsrc, 'r_dtype')
r_dtype_mkt <- dplyr::tbl(pgsrc, 'r_dtype_mkt')
r_odis_ucit <- dplyr::tbl(pgsrc, 'r_odis_ucit')


p_odis_ucit <- inner_join(test, r_odis_ucit %>% group_by(orig_destination_distance, user_location_city, hotel_cluster) %>% summarise(cws=sum(cws))) %>% select(id, hotel_cluster, cws) %>% group_by(id) %>% top_n(5)

p_im <- inner_join(test, r_im %>% group_by(is_mobile, hotel_cluster) %>% summarise(cws=sum(cws))) %>% select(id, hotel_cluster, cws) %>% group_by(id) %>% top_n(5)

p_dtype <- inner_join(test, r_dtype %>% group_by(srch_destination_type_id, hotel_cluster) %>% summarise(cws=sum(cws))) %>% select(id, hotel_cluster, cws) %>% group_by(id) %>% top_n(5)

p_dtype_mkt <- inner_join(test, r_dtype_mkt %>% group_by(srch_destination_type_id, hotel_market, hotel_cluster) %>% summarise(cws=sum(cws))) %>% select(id, hotel_cluster, cws) %>% group_by(id) %>% top_n(5)

