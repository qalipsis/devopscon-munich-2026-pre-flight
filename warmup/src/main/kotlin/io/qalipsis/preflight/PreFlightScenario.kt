package io.qalipsis.preflight

import io.qalipsis.api.annotations.Scenario
import io.qalipsis.api.executionprofile.regular
import io.qalipsis.api.scenario.scenario
import io.qalipsis.api.steps.returns

/**
 * Does nothing. Compiling it makes Gradle download the compiler, the annotation processors and
 * the libraries of QALIPSIS: the scenarios of the workshop need the same ones.
 */
class PreFlightScenario {

    @Scenario("pre-flight")
    fun preFlight() {
        scenario {
            minionsCount = 1
            profile { regular(periodMs = 1000, minionsCountProLaunch = 1) }
        }
            .start()
            .returns { Unit }
    }
}
