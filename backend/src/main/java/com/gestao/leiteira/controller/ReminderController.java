package com.gestao.leiteira.controller;

import com.gestao.leiteira.model.Reminder;
import com.gestao.leiteira.service.ReminderService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reminders")
public class ReminderController {

    private final ReminderService service;

    public ReminderController(ReminderService service) {
        this.service = service;
    }

    @GetMapping
    public List<Reminder> getAll() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public Reminder getById(@PathVariable Long id) {
        return service.findById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Reminder create(@RequestBody Reminder reminder) {
        return service.create(reminder);
    }

    @PutMapping("/{id}")
    public Reminder update(@PathVariable Long id, @RequestBody Reminder reminder) {
        return service.update(id, reminder);
    }

    @PatchMapping("/{id}/status")
    public Reminder updateStatus(@PathVariable Long id, @RequestParam boolean concluido) {
        return service.updateStatus(id, concluido);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
