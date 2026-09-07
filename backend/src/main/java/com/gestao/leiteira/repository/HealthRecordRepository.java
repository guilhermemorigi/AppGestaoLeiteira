package com.gestao.leiteira.repository;

import com.gestao.leiteira.model.HealthRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface HealthRecordRepository extends JpaRepository<HealthRecord, Long> {
    List<HealthRecord> findByAnimalIdOrderByDataDesc(Long animalId);
    List<HealthRecord> findAllByOrderByDataDesc();
}
