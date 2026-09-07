package com.gestao.leiteira.controller;

import com.gestao.leiteira.model.Reproduction;
import com.gestao.leiteira.repository.ReproductionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reproduction")
@CrossOrigin(origins = "*")
public class ReproductionController {

    @Autowired
    private ReproductionRepository repository;

    @GetMapping
    public List<Reproduction> getAll() {
        return repository.findAllByOrderByDataDesc();
    }

    @GetMapping("/animal/{animalId}")
    public List<Reproduction> getByAnimal(@PathVariable Long animalId) {
        return repository.findByAnimalIdOrderByDataDesc(animalId);
    }

    @PostMapping
    public Reproduction create(@RequestBody Reproduction reproduction) {
        return repository.save(reproduction);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Reproduction> update(@PathVariable Long id, @RequestBody Reproduction reproduction) {
        return repository.findById(id)
                .map(existing -> {
                    reproduction.setId(id);
                    return ResponseEntity.ok(repository.save(reproduction));
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
