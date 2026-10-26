package com.gestao.leiteira.controller;

import com.gestao.leiteira.model.Production;
import com.gestao.leiteira.service.ProductionService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/production")
public class ProductionController {

    private final ProductionService service;

    public ProductionController(ProductionService service) {
        this.service = service;
    }

    @GetMapping
    public List<Production> getAll() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public Production getById(@PathVariable Long id) {
        return service.findById(id);
    }

    @GetMapping("/animal/{animalId}")
    public List<Production> getByAnimal(@PathVariable Long animalId) {
        return service.findByAnimal(animalId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Production create(@RequestBody Production production) {
        return service.create(production);
    }

    @PutMapping("/{id}")
    public Production update(@PathVariable Long id, @RequestBody Production production) {
        return service.update(id, production);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
