package com.gestao.leiteira.controller;

import com.gestao.leiteira.model.Production;
import com.gestao.leiteira.repository.ProductionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/production")
@CrossOrigin(origins = "*")
public class ProductionController {

    @Autowired
    private ProductionRepository repository;

    @GetMapping
    public List<Production> getAll() {
        return repository.findAll();
    }

    @GetMapping("/animal/{animalId}")
    public List<Production> getByAnimal(@PathVariable Long animalId) {
        return repository.findByAnimalId(animalId);
    }

    @PostMapping
    public Production create(@RequestBody Production production) {
        return repository.save(production);
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
