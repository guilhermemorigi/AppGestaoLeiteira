package com.gestao.leiteira.controller;

import com.gestao.leiteira.model.Vaccine;
import com.gestao.leiteira.service.VaccineService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/vaccines")
public class VaccineController {

    private final VaccineService service;

    public VaccineController(VaccineService service) {
        this.service = service;
    }

    @GetMapping
    public List<Vaccine> getAll() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public Vaccine getById(@PathVariable Long id) {
        return service.findById(id);
    }

    @GetMapping("/animal/{animalId}")
    public List<Vaccine> getByAnimal(@PathVariable Long animalId) {
        return service.findByAnimal(animalId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Vaccine create(@RequestBody Vaccine vaccine) {
        return service.create(vaccine);
    }

    @PutMapping("/{id}")
    public Vaccine update(@PathVariable Long id, @RequestBody Vaccine vaccine) {
        return service.update(id, vaccine);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
