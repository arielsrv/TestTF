package com.example.testtf;

import org.springframework.boot.SpringApplication;

public class TestTestTfApplication {

    public static void main(String[] args) {
        SpringApplication.from(TestTfApplication::main).with(TestcontainersConfiguration.class).run(args);
    }

}
