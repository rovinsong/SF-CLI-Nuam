/**
 * DTOs de request/response para el servicio REST de Onboarding de Nuam.
 * Contrato v1. Los nombres de propiedad reflejan el JSON acordado con Nuam (provisional).
 */
public with sharing class ED_NuamOnboardingLeadDTO {

    // ---------- Request ----------
    public class OnboardingRequest {
        public String onboardingId;      // External Id / clave de dedup
        public Empresa empresa;
        public UsuarioAdministrador usuarioAdministrador;
        public RepresentanteLegal representanteLegal;
        public Facturacion facturacion;
    }

    public class Empresa {
        public String razonSocial;
        public String rut;
        public String pais;
        public String comuna;
        public String direccion;
        public String rubroComercial;
    }

    public class UsuarioAdministrador {
        public String nombre;
        public String apellido;
        public String telefono;
        public String correo;
        public String cargo;
        public String areaCargo;
    }

    public class RepresentanteLegal {
        public String nombres;
        public String apellidos;
        public String cargo;
        public String correo;
    }

    public class Facturacion {
        public String nombres;
        public String apellidos;
        public String telefono;
        public String cargo;
        public String areaCargo;
        public String pais;
        public String correoFacturacion;
    }

    // ---------- Response ----------
    public class OnboardingResponse {
        public String status;            // created | updated | error
        public String leadId;
        public String dedupKey;
        public String message;
        public List<FieldError> errors;
        public String timestamp;

        public OnboardingResponse() {
            this.errors = new List<FieldError>();
            this.timestamp = String.valueOf(Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        }
    }

    public class FieldError {
        public String field;
        public String code;
        public String detail;
        public FieldError(String field, String code, String detail) {
            this.field = field;
            this.code = code;
            this.detail = detail;
        }
    }
}
