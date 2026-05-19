package com.gestao.leiteira.repository;

import com.gestao.leiteira.model.Production;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ProductionRepository extends JpaRepository<Production, Long> {
    List<Production> findByAnimalId(Long animalId);
}
