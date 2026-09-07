package com.gestao.leiteira.controller;

import com.gestao.leiteira.model.Vaccine;
import com.gestao.leiteira.repository.VaccineRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/vaccines")
@CrossOrigin(origins = "*")
public class VaccineController {

    @Autowired
    private VaccineRepository repository;

    @GetMapping
    public List<Vaccine> getAll() {
        return repository.findAllByOrderByDataAplicacaoDesc();
    }

    @GetMapping("/animal/{animalId}")
    public List<Vaccine> getByAnimal(@PathVariable Long animalId) {
        return repository.findByAnimalIdOrderByDataAplicacaoDesc(animalId);
    }

    @PostMapping
    public Vaccine create(@RequestBody Vaccine vaccine) {
        return repository.save(vaccine);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Vaccine> update(@PathVariable Long id, @RequestBody Vaccine vaccine) {
        return repository.findById(id)
                .map(existing -> {
                    vaccine.setId(id);
                    return ResponseEntity.ok(repository.save(vaccine));
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
