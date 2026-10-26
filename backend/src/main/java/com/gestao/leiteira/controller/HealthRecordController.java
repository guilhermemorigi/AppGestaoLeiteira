package com.gestao.leiteira.controller;

import com.gestao.leiteira.model.HealthRecord;
import com.gestao.leiteira.service.HealthRecordService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/health")
public class HealthRecordController {

    private final HealthRecordService service;

    public HealthRecordController(HealthRecordService service) {
        this.service = service;
    }

    @GetMapping
    public List<HealthRecord> getAll() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public HealthRecord getById(@PathVariable Long id) {
        return service.findById(id);
    }

    @GetMapping("/animal/{animalId}")
    public List<HealthRecord> getByAnimal(@PathVariable Long animalId) {
        return service.findByAnimal(animalId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public HealthRecord create(@RequestBody HealthRecord record) {
        return service.create(record);
    }

    @PutMapping("/{id}")
    public HealthRecord update(@PathVariable Long id, @RequestBody HealthRecord record) {
        return service.update(id, record);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
