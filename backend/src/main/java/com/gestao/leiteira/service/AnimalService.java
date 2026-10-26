package com.gestao.leiteira.service;

import com.gestao.leiteira.exception.ApiException;
import com.gestao.leiteira.model.Animal;
import com.gestao.leiteira.repository.AnimalRepository;
import com.gestao.leiteira.repository.HealthRecordRepository;
import com.gestao.leiteira.repository.ProductionRepository;
import com.gestao.leiteira.repository.ReproductionRepository;
import com.gestao.leiteira.repository.VaccineRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;

@Service
public class AnimalService {

    public static final String STATUS_LACTACAO = "Lactação";
    private static final Set<String> STATUS_INATIVOS = Set.of("Vendido", "Morto");

    private final AnimalRepository repository;
    private final ProductionRepository productionRepository;
    private final HealthRecordRepository healthRepository;
    private final VaccineRepository vaccineRepository;
    private final ReproductionRepository reproductionRepository;

    public AnimalService(AnimalRepository repository,
                         ProductionRepository productionRepository,
                         HealthRecordRepository healthRepository,
                         VaccineRepository vaccineRepository,
                         ReproductionRepository reproductionRepository) {
        this.repository = repository;
        this.productionRepository = productionRepository;
        this.healthRepository = healthRepository;
        this.vaccineRepository = vaccineRepository;
        this.reproductionRepository = reproductionRepository;
    }

    public List<Animal> findAll() {
        return repository.findAllByOrderByNomeAsc();
    }

    public Animal findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Animal não encontrado."));
    }

    /**
     * Resolve a referência {"animal": {"id": X}} enviada pelo app para a entidade
     * completa, garantindo que o animal existe.
     */
    public Animal resolve(Animal ref) {
        if (ref == null || ref.getId() == null) {
            throw ApiException.badRequest("Informe o animal.");
        }
        return repository.findById(ref.getId())
                .orElseThrow(() -> ApiException.badRequest("O animal informado não existe."));
    }

    @Transactional
    public Animal create(Animal animal) {
        animal.setId(null);
        validate(animal);
        if (animal.getStatus() == null || animal.getStatus().isBlank()) {
            animal.setStatus("Ativo");
        }
        return repository.save(animal);
    }

    @Transactional
    public Animal update(Long id, Animal dados) {
        Animal animal = findById(id);
        validate(dados);
        animal.setNome(dados.getNome());
        animal.setIdade(dados.getIdade());
        animal.setRaca(dados.getRaca());
        animal.setNumeroBrinco(dados.getNumeroBrinco());
        animal.setSexo(dados.getSexo());
        animal.setPeso(dados.getPeso());
        animal.setDataNascimento(dados.getDataNascimento());
        if (dados.getStatus() != null && !dados.getStatus().isBlank()) {
            animal.setStatus(dados.getStatus());
        }
        return repository.save(animal);
    }

    @Transactional
    public void delete(Long id) {
        Animal animal = findById(id);
        boolean possuiHistorico = productionRepository.existsByAnimalId(id)
                || healthRepository.existsByAnimalId(id)
                || vaccineRepository.existsByAnimalId(id)
                || reproductionRepository.existsByAnimalId(id);
        if (possuiHistorico) {
            throw ApiException.conflict("O animal \"" + animal.getNome()
                    + "\" possui registros de produção, saúde, vacinação ou reprodução. "
                    + "Para preservar o histórico, altere o status para Vendido ou Morto.");
        }
        repository.delete(animal);
    }

    /** Coloca o animal em lactação (após parto), exceto se já estiver vendido/morto. */
    @Transactional
    public void markAsLactating(Animal animal) {
        if (!STATUS_INATIVOS.contains(animal.getStatus())) {
            animal.setStatus(STATUS_LACTACAO);
            repository.save(animal);
        }
    }

    private void validate(Animal animal) {
        animal.setNome(Validacoes.texto(animal.getNome(), "nome"));
        Validacoes.naoNegativo(animal.getPeso(), "peso");
        if (animal.getIdade() != null && animal.getIdade() < 0) {
            throw ApiException.badRequest("O campo 'idade' não pode ser negativo.");
        }
    }
}
