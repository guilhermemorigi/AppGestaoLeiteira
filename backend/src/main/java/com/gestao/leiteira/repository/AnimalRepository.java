package com.gestao.leiteira.repository;

import com.gestao.leiteira.model.Animal;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AnimalRepository extends JpaRepository<Animal, Long> {
}
