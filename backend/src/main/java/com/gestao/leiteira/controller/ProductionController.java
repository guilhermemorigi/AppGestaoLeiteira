package com.gestao.leiteira.controller;

import com.gestao.leiteira.model.Production;
import com.gestao.leiteira.service.ProductionService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/production")
public class ProductionController {

    private final ProductionService service;

    public ProductionController(ProductionService service) {
        this.service = service;
    }

    @GetMapping
    /** ?desde=yyyy-MM-dd limita ao período (usado pelo dashboard). */
    public List<Production> getAll(@RequestParam(required = false)
                                   @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde) {
        return service.findAll(desde);
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
