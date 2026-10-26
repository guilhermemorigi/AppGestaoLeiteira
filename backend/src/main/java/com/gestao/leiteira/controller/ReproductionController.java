package com.gestao.leiteira.controller;

import com.gestao.leiteira.model.Reproduction;
import com.gestao.leiteira.service.ReproductionService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reproduction")
public class ReproductionController {

    private final ReproductionService service;

    public ReproductionController(ReproductionService service) {
        this.service = service;
    }

    @GetMapping
    public List<Reproduction> getAll() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public Reproduction getById(@PathVariable Long id) {
        return service.findById(id);
    }

    @GetMapping("/animal/{animalId}")
    public List<Reproduction> getByAnimal(@PathVariable Long animalId) {
        return service.findByAnimal(animalId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Reproduction create(@RequestBody Reproduction reproduction) {
        return service.create(reproduction);
    }

    @PutMapping("/{id}")
    public Reproduction update(@PathVariable Long id, @RequestBody Reproduction reproduction) {
        return service.update(id, reproduction);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
