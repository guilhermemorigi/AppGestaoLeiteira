package com.gestao.leiteira.repository;

import com.gestao.leiteira.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    List<User> findAllByOrderByUsernameAsc();
    long countByRoleAndAtivoTrue(String role);
}
