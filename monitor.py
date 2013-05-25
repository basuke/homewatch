# -*- coding: utf-8

import RPi.GPIO as GPIO
import mosquitto
import sys
from datetime import datetime


PINS = (18, 23, 24, 25)     # GPIO ports
SERVER = "mqtt.example.com" # MQTT Server


def main():
    # setup MQTT
    conn = MQTTServer(SERVER)

    # setup GPIO
    GPIO.setmode(GPIO.BCM)
    [GPIO.setup(pin, GPIO.IN) for pin in PINS]

    labels = range(1, len(PINS) + 1)
    sensors = [Sensor(label, pin) for label, pin in zip(labels, PINS)]

    def on_connect():
        # send initial state
        for sensor in sensors:
            conn.publish(*sensor.event())

        conn.publish("home/kitchen/monitor", "ON")

    conn.set_will("home/kitchen/monitor", "OFF")
    conn.connect(on_connect)

    while True:
        conn.loop()

        for sensor in sensors:
            if sensor.check():
                conn.publish(*sensor.event())


class Sensor(object):
    def __init__(self, label, pin):
        self.pin = pin
        self.state = GPIO.input(self.pin)
        self.topic = "home/kitchen/gas/%s" % label

    def check(self):
        state = self.state
        self.state = GPIO.input(self.pin)
        return (state != self.state)

    def event(self):
        state = "ON" if self.state else "OFF"
        msg = ' '.join([state, utctimestamp()])

        return (self.topic, msg)


class MQTTServer(object):
    def __init__(self, server):
        self.server = server
        self.client = mosquitto.Mosquitto("Daidokoro-monitor", userdata=self)
        self.connected = False
        self.on_connect = None

        def on_connect(mosq, self, rc):
            if rc != 0:
                log("Cannot connect to server. Exit.")
                sys.exit(255)

            log("Connected successfully.")
            self.connected = True

            if self.on_connect:
                self.on_connect()

        def on_disconnect(mosq, self, rc):
            log("Disconnected. Try to connect again.")
            self.connected = False

            self.reconnect()

        self.client.on_connect = on_connect
        self.client.on_disconnect = on_disconnect

    def connect(self, on_connect):
        log("Connecting to MQTT server.")
        self.on_connect = on_connect

        self.client.connect(self.server, keepalive=10)
        self.wait_connection()

    def reconnect(self):
        log("Reconnecting to MQTT server.")
        self.client.reconnect()
        self.wait_connection()

    def publish(self, topic, payload):
        log("Publish %s => %s" % (topic, payload))
        self.client.publish(topic, payload, retain=True)

    def set_will(self, topic, payload):
        log("Set Will %s => %s" % (topic, payload))
        self.client.will_set(topic, payload, retain=True)

    def loop(self, timeout=0.1):
        self.client.loop(timeout=timeout)

    def wait_connection(self):
        while not self.connected:
            self.loop()


def utctimestamp():
    now = datetime.utcnow().replace(microsecond = 0)
    return now.isoformat() + 'Z'

def log(msg):
    print msg


if __name__ == '__main__':
    main()
