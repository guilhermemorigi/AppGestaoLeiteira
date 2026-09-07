package com.gestao.leiteira.controller;

import com.gestao.leiteira.model.HealthRecord;
import com.gestao.leiteira.repository.HealthRecordRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/health")
@CrossOrigin(origins = "*")
public class HealthRecordController {

    @Autowired
    private HealthRecordRepository repository;

    @GetMapping
    public List<HealthRecord> getAll() {
        return repository.findAllByOrderByDataDesc();
    }

    @GetMapping("/animal/{animalId}")
    public List<HealthRecord> getByAnimal(@PathVariable Long animalId) {
        return repository.findByAnimalIdOrderByDataDesc(animalId);
    }

    @PostMapping
    public HealthRecord create(@RequestBody HealthRecord record) {
        return repository.save(record);
    }

    @PutMapping("/{id}")
    public ResponseEntity<HealthRecord> update(@PathVariable Long id, @RequestBody HealthRecord record) {
        return repository.findById(id)
                .map(existing -> {
                    record.setId(id);
                    return ResponseEntity.ok(repository.save(record));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        if (!repository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        repository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
