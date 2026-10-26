package com.gestao.leiteira.repository;

import com.gestao.leiteira.model.Reminder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ReminderRepository extends JpaRepository<Reminder, Long> {
    // Pendentes primeiro, depois por data (mais próximos no topo)
    List<Reminder> findAllByOrderByConcluidoAscDataAsc();
}
