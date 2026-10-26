package com.gestao.leiteira.service;

import com.gestao.leiteira.exception.ApiException;
import com.gestao.leiteira.model.Reminder;
import com.gestao.leiteira.repository.ReminderRepository;
import com.gestao.leiteira.repository.VaccineRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ReminderService {

    private final ReminderRepository repository;
    private final VaccineRepository vaccineRepository;

    public ReminderService(ReminderRepository repository, VaccineRepository vaccineRepository) {
        this.repository = repository;
        this.vaccineRepository = vaccineRepository;
    }

    public List<Reminder> findAll() {
        return repository.findAllByOrderByConcluidoAscDataAsc();
    }

    public Reminder findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Lembrete não encontrado."));
    }

    @Transactional
    public Reminder create(Reminder reminder) {
        reminder.setId(null);
        reminder.setOrigem(null); // lembretes manuais
        validate(reminder);
        if (reminder.getConcluido() == null) reminder.setConcluido(false);
        return repository.save(reminder);
    }

    @Transactional
    public Reminder update(Long id, Reminder dados) {
        Reminder reminder = findById(id);
        validate(dados);
        reminder.setTitulo(dados.getTitulo());
        reminder.setDescricao(dados.getDescricao());
        reminder.setData(dados.getData());
        if (dados.getConcluido() != null) reminder.setConcluido(dados.getConcluido());
        return repository.save(reminder);
    }

    @Transactional
    public Reminder updateStatus(Long id, boolean concluido) {
        Reminder reminder = findById(id);
        reminder.setConcluido(concluido);
        return repository.save(reminder);
    }

    @Transactional
    public void delete(Long id) {
        Reminder reminder = findById(id);
        // Lembrete de vacina: desvincula da vacina (orphanRemoval apaga o lembrete)
        vaccineRepository.findByLembreteId(id).ifPresentOrElse(
                vaccine -> vaccine.setLembrete(null),
                () -> repository.delete(reminder));
    }

    private void validate(Reminder reminder) {
        reminder.setTitulo(Validacoes.texto(reminder.getTitulo(), "título"));
        Validacoes.obrigatorio(reminder.getData(), "data");
    }
}
