package com.gestao.leiteira.repository;

import com.gestao.leiteira.model.Production;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ProductionRepository extends JpaRepository<Production, Long> {
    List<Production> findByAnimalIdOrderByDataDesc(Long animalId);
    List<Production> findAllByOrderByDataDesc();
    List<Production> findByDataGreaterThanEqualOrderByDataDesc(LocalDateTime desde);
    boolean existsByAnimalId(Long animalId);
}
