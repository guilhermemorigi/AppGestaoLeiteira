package com.gestao.leiteira.controller;

import com.gestao.leiteira.model.Reminder;
import com.gestao.leiteira.repository.ReminderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reminders")
@CrossOrigin(origins = "*")
public class ReminderController {

    @Autowired
    private ReminderRepository repository;

    @GetMapping
    public List<Reminder> getAll() {
        return repository.findAll();
    }

    @PostMapping
    public Reminder create(@RequestBody Reminder reminder) {
        return repository.save(reminder);
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<Reminder> updateStatus(@PathVariable Long id, @RequestParam Boolean concluido) {
        return repository.findById(id)
                .map(reminder -> {
                    reminder.setConcluido(concluido);
                    return ResponseEntity.ok(repository.save(reminder));
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
