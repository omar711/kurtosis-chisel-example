

def run(plan, args):

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

    chisel_connection = engine_chisel_server.ip_address + ":" + str(engine_chisel_server.ports["chisel-server"].number)
    web1_tunnel = "0.0.0.0" + ":" + "9201" + ":" + web1.ip_address + ":" + str(web1.ports["http"].number)
    web2_tunnel = "0.0.0.0" + ":" + "9202" + ":" + web2.ip_address + ":" + str(web2.ports["http"].number)
    # web3 not invented yet

    front_door_chisel = plan.add_service(
        name = "front-door-chisel",
        config = ServiceConfig(
            image = "jpillora/chisel:latest",
            cmd = ["client", chisel_connection, web1_tunnel, web2_tunnel],
            ports = {
                # http here because we're forwarding to the web server (just a convenience thing)
                "front-web-1": PortSpec(9201, application_protocol="http"),
                "front-web-2": PortSpec(9202, application_protocol="http"),
            }
        )
    )


