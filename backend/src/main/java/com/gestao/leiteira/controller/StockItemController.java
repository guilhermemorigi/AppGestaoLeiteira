package com.gestao.leiteira.controller;

import com.gestao.leiteira.model.StockItem;
import com.gestao.leiteira.repository.StockItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/stock")
@CrossOrigin(origins = "*")
public class StockItemController {

    @Autowired
    private StockItemRepository repository;

    @GetMapping
    public List<StockItem> getAll() {
        return repository.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<StockItem> getById(@PathVariable Long id) {
        return repository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public StockItem create(@RequestBody StockItem item) {
        return repository.save(item);
    }

    @PutMapping("/{id}")
    public ResponseEntity<StockItem> update(@PathVariable Long id, @RequestBody StockItem item) {
        return repository.findById(id)
                .map(existing -> {
                    item.setId(id);
                    return ResponseEntity.ok(repository.save(item));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/{id}/quantidade")
    public ResponseEntity<StockItem> adjustQuantity(@PathVariable Long id, @RequestParam Double delta) {
        return repository.findById(id)
                .map(item -> {
                    double atual = item.getQuantidade() == null ? 0 : item.getQuantidade();
                    double novo = atual + delta;
                    item.setQuantidade(novo < 0 ? 0 : novo);
                    return ResponseEntity.ok(repository.save(item));
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
