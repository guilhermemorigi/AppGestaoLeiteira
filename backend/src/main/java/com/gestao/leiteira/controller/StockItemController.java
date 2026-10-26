package com.gestao.leiteira.controller;

import com.gestao.leiteira.model.StockItem;
import com.gestao.leiteira.service.StockItemService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/stock")
public class StockItemController {

    private final StockItemService service;

    public StockItemController(StockItemService service) {
        this.service = service;
    }

    @GetMapping
    public List<StockItem> getAll() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public StockItem getById(@PathVariable Long id) {
        return service.findById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public StockItem create(@RequestBody StockItem item) {
        return service.create(item);
    }

    @PutMapping("/{id}")
    public StockItem update(@PathVariable Long id, @RequestBody StockItem item) {
        return service.update(id, item);
    }

    /** Entrada (delta positivo) ou saída (delta negativo) de estoque. */
    @PatchMapping("/{id}/quantidade")
    public StockItem adjustQuantity(@PathVariable Long id, @RequestParam double delta) {
        return service.adjustQuantity(id, delta);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
