package com.gestao.leiteira.service;

import com.gestao.leiteira.exception.ApiException;
import com.gestao.leiteira.model.Expense;
import com.gestao.leiteira.repository.ExpenseRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ExpenseService {

    private final ExpenseRepository repository;

    public ExpenseService(ExpenseRepository repository) {
        this.repository = repository;
    }

    public List<Expense> findAll() {
        return repository.findAllByOrderByDataDesc();
    }

    public Expense findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Despesa não encontrada."));
    }

    @Transactional
    public Expense create(Expense expense) {
        expense.setId(null);
        expense.setOrigem(null); // lançamentos manuais
        validate(expense);
        return repository.save(expense);
    }

    @Transactional
    public Expense update(Long id, Expense dados) {
        Expense expense = findById(id);
        ensureManual(expense);
        validate(dados);
        expense.setDescricao(dados.getDescricao());
        expense.setValor(dados.getValor());
        expense.setData(dados.getData());
        expense.setCategoria(dados.getCategoria());
        return repository.save(expense);
    }

    @Transactional
    public void delete(Long id) {
        Expense expense = findById(id);
        ensureManual(expense);
        repository.delete(expense);
    }

    /** Despesas geradas por registros de saúde são mantidas pelo próprio registro. */
    private void ensureManual(Expense expense) {
        if (HealthRecordService.ORIGEM_SAUDE.equals(expense.getOrigem())) {
            throw ApiException.conflict("Esta despesa foi gerada automaticamente por um registro de saúde. "
                    + "Altere o custo ou exclua o registro em Saúde & Tratamentos.");
        }
    }

    private void validate(Expense expense) {
        expense.setDescricao(Validacoes.texto(expense.getDescricao(), "descrição"));
        Validacoes.positivo(expense.getValor(), "valor");
        Validacoes.obrigatorio(expense.getData(), "data");
    }
}
