package com.gestao.leiteira.repository;

import com.gestao.leiteira.model.Vaccine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface VaccineRepository extends JpaRepository<Vaccine, Long> {
    List<Vaccine> findByAnimalIdOrderByDataAplicacaoDesc(Long animalId);
    List<Vaccine> findAllByOrderByDataAplicacaoDesc();
}
