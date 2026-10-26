package com.gestao.leiteira.service;

import com.gestao.leiteira.exception.ApiException;
import com.gestao.leiteira.model.Expense;
import com.gestao.leiteira.model.HealthRecord;
import com.gestao.leiteira.repository.HealthRecordRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class HealthRecordService {

    public static final String ORIGEM_SAUDE = "SAUDE";
    static final String CATEGORIA_DESPESA = "Veterinário";

    private final HealthRecordRepository repository;
    private final AnimalService animalService;

    public HealthRecordService(HealthRecordRepository repository, AnimalService animalService) {
        this.repository = repository;
        this.animalService = animalService;
    }

    public List<HealthRecord> findAll() {
        return repository.findAllByOrderByDataDesc();
    }

    public List<HealthRecord> findByAnimal(Long animalId) {
        return repository.findByAnimalIdOrderByDataDesc(animalId);
    }

    public HealthRecord findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Registro de saúde não encontrado."));
    }

    @Transactional
    public HealthRecord create(HealthRecord record) {
        record.setId(null);
        record.setDespesa(null);
        validate(record);
        record.setAnimal(animalService.resolve(record.getAnimal()));
        if (record.getStatus() == null || record.getStatus().isBlank()) {
            record.setStatus("Em andamento");
        }
        syncExpense(record);
        return repository.save(record);
    }

    @Transactional
    public HealthRecord update(Long id, HealthRecord dados) {
        HealthRecord record = findById(id);
        validate(dados);
        record.setAnimal(animalService.resolve(dados.getAnimal()));
        record.setTipo(dados.getTipo());
        record.setDescricao(dados.getDescricao());
        record.setMedicamento(dados.getMedicamento());
        record.setVeterinario(dados.getVeterinario());
        record.setData(dados.getData());
        record.setDataFim(dados.getDataFim());
        record.setCusto(dados.getCusto());
        if (dados.getStatus() != null && !dados.getStatus().isBlank()) {
            record.setStatus(dados.getStatus());
        }
        record.setObservacao(dados.getObservacao());
        syncExpense(record);
        return repository.save(record);
    }

    @Transactional
    public void delete(Long id) {
        // A despesa vinculada é removida em cascata
        repository.delete(findById(id));
    }

    /**
     * Mantém a despesa automática alinhada ao custo do registro: cria quando há
     * custo, atualiza quando muda e remove quando o custo é zerado.
     */
    private void syncExpense(HealthRecord record) {
        double custo = record.getCusto() == null ? 0 : record.getCusto();
        if (custo <= 0) {
            record.setDespesa(null);
            return;
        }
        Expense despesa = record.getDespesa();
        if (despesa == null) {
            despesa = new Expense();
            despesa.setOrigem(ORIGEM_SAUDE);
            record.setDespesa(despesa);
        }
        String descricao = record.getTipo() + ": " + record.getDescricao()
                + " (" + record.getAnimal().getNome() + ")";
        despesa.setDescricao(Validacoes.limitar(descricao, 255));
        despesa.setValor(custo);
        despesa.setData(record.getData());
        despesa.setCategoria(CATEGORIA_DESPESA);
    }

    private void validate(HealthRecord record) {
        record.setTipo(Validacoes.texto(record.getTipo(), "tipo"));
        record.setDescricao(Validacoes.texto(record.getDescricao(), "descrição"));
        Validacoes.obrigatorio(record.getData(), "data");
        Validacoes.naoNegativo(record.getCusto(), "custo");
        if (record.getCusto() == null) record.setCusto(0.0);
    }
}
