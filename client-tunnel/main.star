
POSTGRES_DB = "app_db"
POSTGRES_USER = "app_user"
POSTGRES_PASSWORD = "password"

def run(plan, args):

    udp_listener = plan.add_service(
        name = "udp-listener",
        config = ServiceConfig(
            image = "mendhak/udp-listener",
            ports = {
                "udp-listener": PortSpec(4444, transport_protocol="UDP", application_protocol="udp")
            },
            env_vars = {
                "UDPPORT": "4444"
            }
        )
    )

    postgres = plan.add_service(
        name = "postgres",
        config = ServiceConfig(
            image = "postgres:15.2-alpine",
            ports = {
                "postgresql": PortSpec(5432, application_protocol = "postgresql"),
            },
            env_vars = {
                "POSTGRES_DB": POSTGRES_DB,
                "POSTGRES_USER": POSTGRES_USER,
                "POSTGRES_PASSWORD": POSTGRES_PASSWORD,
            },
        ),
    )

    html1 = plan.upload_files("./data/web1/index.html")
    html2 = plan.upload_files("./data/web2/index.html")

    web1 = plan.add_service(
        name = "web1",
        config = ServiceConfig(
            image = "httpd:2.4.57-alpine",
            ports = {
                "http": PortSpec(80, application_protocol="http")
            },
            files = {
                "/usr/local/apache2/htdocs": html1
            },
        )
    )

    web2 = plan.add_service(
        name = "web2",
        config = ServiceConfig(
            image = "httpd:2.4.57-alpine",
            ports = {
                "http": PortSpec(80, application_protocol="http")
            },
            files = {
                "/usr/local/apache2/htdocs": html2
            },
        )
    )

    engine_chisel_server = plan.add_service(
        name = "engine-chisel",
        config = ServiceConfig(
            image = "jpillora/chisel:latest",
            cmd = ["server", "--port", "9200"],
            ports = {
                "chisel-server": PortSpec(9200, application_protocol="tcp")
            },
        )
    )

    front_to_engine_chisel_connection = engine_chisel_server.ip_address + ":" + str(engine_chisel_server.ports["chisel-server"].number)
    front_to_engine_tunnel = "9200:" + str(engine_chisel_server.ports["chisel-server"].number)

    front_door_chisel_client = plan.add_service(
        name = "front-door-chisel-client",
        config = ServiceConfig(
            image = "jpillora/chisel:latest",
            cmd = ["client", front_to_engine_chisel_connection, front_to_engine_tunnel],
            ports = {
                "chisel-tunnel": PortSpec(9200, application_protocol="tcp")
            }
        )
    )


