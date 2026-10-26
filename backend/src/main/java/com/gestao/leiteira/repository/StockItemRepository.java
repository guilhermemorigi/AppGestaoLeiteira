package com.gestao.leiteira.repository;

import com.gestao.leiteira.model.StockItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface StockItemRepository extends JpaRepository<StockItem, Long> {
    List<StockItem> findAllByOrderByNomeAsc();
}
