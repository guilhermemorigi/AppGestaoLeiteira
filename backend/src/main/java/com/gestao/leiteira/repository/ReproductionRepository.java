package com.gestao.leiteira.repository;

import com.gestao.leiteira.model.Reproduction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ReproductionRepository extends JpaRepository<Reproduction, Long> {
    List<Reproduction> findByAnimalIdOrderByDataDesc(Long animalId);
    List<Reproduction> findAllByOrderByDataDesc();
}
