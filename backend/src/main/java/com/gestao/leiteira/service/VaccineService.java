package com.gestao.leiteira.service;

import com.gestao.leiteira.exception.ApiException;
import com.gestao.leiteira.model.Animal;
import com.gestao.leiteira.model.Reminder;
import com.gestao.leiteira.model.Vaccine;
import com.gestao.leiteira.repository.VaccineRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;

@Service
public class VaccineService {

    public static final String ORIGEM_VACINA = "VACINA";

    private final VaccineRepository repository;
    private final AnimalService animalService;

    public VaccineService(VaccineRepository repository, AnimalService animalService) {
        this.repository = repository;
        this.animalService = animalService;
    }

    public List<Vaccine> findAll() {
        return repository.findAllByOrderByDataAplicacaoDesc();
    }

    public List<Vaccine> findByAnimal(Long animalId) {
        return repository.findByAnimalIdOrderByDataAplicacaoDesc(animalId);
    }

    public Vaccine findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Vacina não encontrada."));
    }

    @Transactional
    public Vaccine create(Vaccine vaccine) {
        vaccine.setId(null);
        vaccine.setLembrete(null);
        validate(vaccine);
        vaccine.setAnimal(animalService.resolve(vaccine.getAnimal()));
        syncReminder(vaccine);
        return repository.save(vaccine);
    }

    @Transactional
    public Vaccine update(Long id, Vaccine dados) {
        Vaccine vaccine = findById(id);
        validate(dados);
        vaccine.setAnimal(animalService.resolve(dados.getAnimal()));
        vaccine.setNome(dados.getNome());
        vaccine.setDataAplicacao(dados.getDataAplicacao());
        vaccine.setProximaDose(dados.getProximaDose());
        vaccine.setLote(dados.getLote());
        vaccine.setVeterinario(dados.getVeterinario());
        vaccine.setObservacao(dados.getObservacao());
        syncReminder(vaccine);
        return repository.save(vaccine);
    }

    @Transactional
    public void delete(Long id) {
        // O lembrete da próxima dose é removido em cascata
        repository.delete(findById(id));
    }

    /**
     * Mantém um lembrete na Agenda para a próxima dose: cria quando há data,
     * atualiza quando muda e remove quando a próxima dose é desmarcada.
     */
    private void syncReminder(Vaccine vaccine) {
        if (vaccine.getProximaDose() == null) {
            vaccine.setLembrete(null);
            return;
        }
        Reminder lembrete = vaccine.getLembrete();
        if (lembrete == null) {
            lembrete = new Reminder();
            lembrete.setOrigem(ORIGEM_VACINA);
            lembrete.setConcluido(false);
            vaccine.setLembrete(lembrete);
        } else if (!Objects.equals(lembrete.getData(), vaccine.getProximaDose())) {
            lembrete.setConcluido(false); // nova data, nova pendência
        }
        Animal animal = vaccine.getAnimal();
        String identificacao = animal.getNome()
                + (animal.getNumeroBrinco() != null && !animal.getNumeroBrinco().isBlank()
                    ? " (brinco " + animal.getNumeroBrinco() + ")" : "");
        lembrete.setTitulo(Validacoes.limitar("Vacina: " + vaccine.getNome() + " - " + animal.getNome(), 255));
        lembrete.setDescricao(Validacoes.limitar(
                "Próxima dose da vacina " + vaccine.getNome() + " para " + identificacao + ".", 255));
        lembrete.setData(vaccine.getProximaDose());
    }

    private void validate(Vaccine vaccine) {
        vaccine.setNome(Validacoes.texto(vaccine.getNome(), "nome da vacina"));
        Validacoes.obrigatorio(vaccine.getDataAplicacao(), "data de aplicação");
        if (vaccine.getProximaDose() != null
                && vaccine.getProximaDose().isBefore(vaccine.getDataAplicacao())) {
            throw ApiException.badRequest("A próxima dose não pode ser anterior à data de aplicação.");
        }
    }
}
