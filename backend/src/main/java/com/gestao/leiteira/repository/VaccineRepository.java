package com.gestao.leiteira.repository;

import com.gestao.leiteira.model.Vaccine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface VaccineRepository extends JpaRepository<Vaccine, Long> {
    List<Vaccine> findByAnimalIdOrderByDataAplicacaoDesc(Long animalId);
    List<Vaccine> findAllByOrderByDataAplicacaoDesc();
    boolean existsByAnimalId(Long animalId);
    Optional<Vaccine> findByLembreteId(Long reminderId);
}
