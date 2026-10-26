package com.gestao.leiteira.service;

import com.gestao.leiteira.exception.ApiException;
import com.gestao.leiteira.model.StockItem;
import com.gestao.leiteira.repository.StockItemRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class StockItemService {

    private final StockItemRepository repository;

    public StockItemService(StockItemRepository repository) {
        this.repository = repository;
    }

    public List<StockItem> findAll() {
        return repository.findAllByOrderByNomeAsc();
    }

    public StockItem findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Item de estoque não encontrado."));
    }

    @Transactional
    public StockItem create(StockItem item) {
        item.setId(null);
        validate(item);
        return repository.save(item);
    }

    @Transactional
    public StockItem update(Long id, StockItem dados) {
        StockItem item = findById(id);
        validate(dados);
        item.setNome(dados.getNome());
        item.setCategoria(dados.getCategoria());
        item.setQuantidade(dados.getQuantidade());
        item.setUnidade(dados.getUnidade());
        item.setQuantidadeMinima(dados.getQuantidadeMinima());
        item.setPrecoUnitario(dados.getPrecoUnitario());
        item.setValidade(dados.getValidade());
        item.setObservacao(dados.getObservacao());
        return repository.save(item);
    }

    /** Entrada (delta positivo) ou saída (delta negativo); nunca fica abaixo de zero. */
    @Transactional
    public StockItem adjustQuantity(Long id, double delta) {
        StockItem item = findById(id);
        double atual = item.getQuantidade() == null ? 0 : item.getQuantidade();
        item.setQuantidade(Math.max(0, atual + delta));
        return repository.save(item);
    }

    @Transactional
    public void delete(Long id) {
        repository.delete(findById(id));
    }

    private void validate(StockItem item) {
        item.setNome(Validacoes.texto(item.getNome(), "nome"));
        if (item.getQuantidade() == null) item.setQuantidade(0.0);
        if (item.getQuantidadeMinima() == null) item.setQuantidadeMinima(0.0);
        if (item.getPrecoUnitario() == null) item.setPrecoUnitario(0.0);
        Validacoes.naoNegativo(item.getQuantidade(), "quantidade");
        Validacoes.naoNegativo(item.getQuantidadeMinima(), "quantidade mínima");
        Validacoes.naoNegativo(item.getPrecoUnitario(), "preço unitário");
    }
}
